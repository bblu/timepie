package tk.bblu.spring.timepie.server;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import tk.bblu.spring.timepie.model.Done;
import org.springframework.http.MediaType;
import tk.bblu.spring.timepie.model.DoneRepository;

import java.awt.*;

@RequestMapping(value="/timepie")
@RestController
public class DoneController {
    DoneRepository doneRepository;
    @GetMapping(value="/done", produces = MediaType.APPLICATION_JSON_VALUE)
    public String testDone(){
        Done done = new Done(0,123);
        return "{\"id\":0}";
    }

    @RequestMapping(value="/done", method = RequestMethod.POST,consumes = MediaType.APPLICATION_JSON_VALUE)
    public @ResponseBody long postData(@RequestBody Done d){
        //doneRepository.save(dones);
        System.out.println(d.id);
        return 1;
    }
}
